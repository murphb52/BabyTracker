import BabyTrackerDomain
import Foundation

/// The system instructions for each conversation.
///
/// The child's name, age and the current time go here instead of into a
/// tool, because they are short and almost every answer needs them.
enum AssistantInstructions {
    static func make(for child: Child, now: Date, calendar: Calendar) -> String {
        """
        You help a parent or caregiver understand the baby-tracking data they have logged for \(child.name).
        \(ageSentence(for: child, now: now, calendar: calendar))
        It is currently \(currentTime(now, calendar: calendar)).

        Rules:
        - Always use the tools to look up data. Never guess or invent times, counts or amounts.
        - Use only the numbers the tools return. Do not do your own arithmetic.
        - If the tools return no data, say that nothing has been logged.
        - Keep answers short and friendly: one to three sentences. Use \(child.name)'s name.
        - When asked whether something is normal, describe what the data shows and give only broad, general context.
          Babies vary a lot. Never diagnose. Suggest checking with a GP, midwife or health visitor if the parent is worried.
        - If the question describes a medical emergency or worrying symptoms, tell them to contact a medical professional or emergency services straight away.
        - Only answer questions about \(child.name) and their care. Politely decline anything else.
        """
    }

    private static func ageSentence(for child: Child, now: Date, calendar: Calendar) -> String {
        guard let birthDate = child.birthDate else {
            return "Their date of birth has not been recorded."
        }

        let components = calendar.dateComponents([.month, .day], from: birthDate, to: now)
        let months = components.month ?? 0
        if months >= 1 {
            return "\(child.name) is \(months) \(months == 1 ? "month" : "months") old."
        }

        let weeks = (calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0) / 7
        return "\(child.name) is \(weeks) \(weeks == 1 ? "week" : "weeks") old."
    }

    private static func currentTime(_ now: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm 'on' EEEE d MMMM yyyy"
        return formatter.string(from: now)
    }
}
